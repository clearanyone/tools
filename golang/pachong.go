package main

import (
	"bytes"
	"database/sql"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"math/rand"
	"net/http"
	"os"
	"regexp"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/PuerkitoBio/goquery"
	_ "github.com/go-sql-driver/mysql"
)

var waitgroup sync.WaitGroup

//var waitgroup2 sync.WaitGroup
var urlChannel = make(chan string, 200)
var chapterChannel = make(chan chapter, 200)
var execChans = make(chan bool, 80) // 控制并发数量的通道，第二个参数指定通道可以容纳的数量，会阻塞执行

var atagRegExp = regexp.MustCompile(`<a[^>]+[(href)|(HREF)]\s*\t*\n*=\s*\t*\n*[(".+")|('.+')][^>]*>[^<]*</a>`) //以Must前缀的方法或函数都是必须保证一定能执行成功的,否则将引发一次panic

var userAgent = [...]string{"Mozilla/5.0 (compatible, MSIE 10.0, Windows NT, DigExt)",
	"Mozilla/4.0 (compatible, MSIE 7.0, Windows NT 5.1, 360SE)",
	"Mozilla/4.0 (compatible, MSIE 8.0, Windows NT 6.0, Trident/4.0)",
	"Mozilla/5.0 (compatible, MSIE 9.0, Windows NT 6.1, Trident/5.0,",
	"Opera/9.80 (Windows NT 6.1, U, en) Presto/2.8.131 Version/11.11",
	"Mozilla/4.0 (compatible, MSIE 7.0, Windows NT 5.1, TencentTraveler 4.0)",
	"Mozilla/5.0 (Windows, U, Windows NT 6.1, en-us) AppleWebKit/534.50 (KHTML, like Gecko) Version/5.1 Safari/534.50",
	"Mozilla/5.0 (Macintosh, Intel Mac OS X 10_7_0) AppleWebKit/535.11 (KHTML, like Gecko) Chrome/17.0.963.56 Safari/535.11",
	"Mozilla/5.0 (Macintosh, U, Intel Mac OS X 10_6_8, en-us) AppleWebKit/534.50 (KHTML, like Gecko) Version/5.1 Safari/534.50",
	"Mozilla/5.0 (Linux, U, Android 3.0, en-us, Xoom Build/HRI39) AppleWebKit/534.13 (KHTML, like Gecko) Version/4.0 Safari/534.13",
	"Mozilla/5.0 (iPad, U, CPU OS 4_3_3 like Mac OS X, en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5",
	"Mozilla/4.0 (compatible, MSIE 7.0, Windows NT 5.1, Trident/4.0, SE 2.X MetaSr 1.0, SE 2.X MetaSr 1.0, .NET CLR 2.0.50727, SE 2.X MetaSr 1.0)",
	"Mozilla/5.0 (iPhone, U, CPU iPhone OS 4_3_3 like Mac OS X, en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5",
	"MQQBrowser/26 Mozilla/5.0 (Linux, U, Android 2.3.7, zh-cn, MB200 Build/GRJ22, CyanogenMod-7) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1"}

var r = rand.New(rand.NewSource(time.Now().UnixNano()))

type chapter struct {
	bookid int64
	title  string //注意后面不能有逗号
	url    string
}

func GetRandomUserAgent() string {
	return userAgent[r.Intn(len(userAgent))]
}

func Spy(baseUrl string, i int) {

	b := bytes.Buffer{}
	b.WriteString(baseUrl)
	b.WriteString(fmt.Sprintf("%d", i))
	b.WriteString(".html")
	url := b.String()
	fmt.Println(url)
	defer func() {
		if r := recover(); r != nil {
			log.Println("[E]", r)
		}
	}()
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Set("User-Agent", GetRandomUserAgent())
	client := http.DefaultClient
	res, e := client.Do(req)
	if e != nil {
		fmt.Errorf("Get请求%s返回错误:%s", url, e)
		return
	}
	if res.StatusCode == 200 {
		doc, _ := goquery.NewDocumentFromResponse(res)
		t := doc.Find("#content table a")

		for i := 0; i < t.Length(); i++ {
			d, _ := t.Eq(i).Attr("href")
			if i%2 == 0 {
				urlChannel <- d
			}
		}
	}
	fmt.Println("爬取页数", i)

}

func Book(url string) {
	defer func() {
		//waitgroup.Done()
		if r := recover(); r != nil {
			log.Println("[E]", r)
		}
	}()
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Set("User-Agent", GetRandomUserAgent())
	client := http.DefaultClient
	res, e := client.Do(req)
	if e != nil {
		fmt.Errorf("Get请求%s返回错误:%s", url, e)
		return
	}
	if res.StatusCode == 200 {
		doc, _ := goquery.NewDocumentFromResponse(res)
		id := getChapterId(url)
		title := doc.Find("#content dd h1").Text()
		pindao := doc.Find("#content #at a").Text()
		auther := doc.Find("#content #at td").Eq(1).Text()
		desc := doc.Find("#content dd").Eq(3).Find("p").Eq(1).Text()
		lastTime := doc.Find("#content #at td").Eq(5).Text()
		pic, _ := doc.Find("#content .hst img").Attr("src")
		listUrl, _ := doc.Find("#content .btnlinks a.read").Attr("href")

		go downpic(pic)

		//fmt.Println(strings.Trim(lastTime, ""))
		//fmt.Println(strings.Replace(title, " 全文阅读", "", -1), auther, getImgName(pic), strings.Replace(desc, "  ", "", -1), 1, getCateId(pindao), getTimeStamp(strings.Trim(lastTime, "")), listUrl)
		bookId, berror := insertBookData(id, strings.Replace(title, " 全文阅读", "", -1), auther, getImgName(pic), strings.Replace(desc, "  ", "", -1), 0, getCateId(pindao), getTimeStamp(strings.Trim(lastTime, "")))
		//fmt.Println("bookId", bookId, berror)
		if berror == nil {
			fmt.Println("bookId", bookId)
			go getChapterList(listUrl, bookId)
		}
	}
}

func insertBookData(id int, title string, author string, pic string, desc string, w_status int, cate_id int, lasttime int64) (int64, error) {
	//tx, _ := db.Begin()
	//fmt.Println("INSERT INTO mymvc_book (title, author,pic,desc,w_status,cate_id,lasttime) VALUES (?,?,?,?,?,?,?)", title, author, pic, desc, w_status, cate_id, lasttime)
	t := time.Now()
	ret, err := db.Exec("replace  INTO mymvc_book(`id`,`title`,`author`,`pic`,`desc`,`w_status`,`cate_id`,`addtime`,`lasttime`) VALUES (?,?,?,?,?,?,?,?,?)", id, title, author, pic, desc, w_status, cate_id, t.Unix(), lasttime)
	if err != nil {
		fmt.Printf("insert data error: %v\n", err)
		return 0, err
	}
	if LastInsertId, err := ret.LastInsertId(); nil == err {
		//fmt.Println("Bookid:", LastInsertId)
		return LastInsertId, nil
	}
	return 0, nil
}

//获取章节连接
func getChapterList(url string, bookid int64) {
	defer func() {
		if r := recover(); r != nil {
			log.Println("[E]", r)
		}
	}()
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Set("User-Agent", GetRandomUserAgent())
	client := http.DefaultClient
	res, e := client.Do(req)
	if e != nil {
		fmt.Errorf("Get请求%s返回错误:%s", url, e)
		return
	}

	if res.StatusCode == 200 {
		doc, _ := goquery.NewDocumentFromResponse(res)
		doc.Find("#at .L a").Each(func(i int, s *goquery.Selection) {
			chapterUrl, _ := s.Attr("href")
			fmt.Println(bookid, s.Text(), chapterUrl)
			p := chapter{
				bookid: bookid,   //注意后面要加逗号
				title:  s.Text(), //或者下面的}提到这儿来可以省略逗号
				url:    chapterUrl,
			}
			chapterChannel <- p
			//waitgroup2.Add(1)
		})
	}
	return
}
func getChapterId(url string) int {
	strings.LastIndex(url, "/")
	a1 := strings.Split(url, "/")
	cid := a1[len(a1)-1]
	chapid, _ := strconv.Atoi(strings.Replace(cid, ".html", "", -1))
	return chapid
}

//获取章节连接
func getChapterContent(chap chapter) {
	<-execChans

	req, _ := http.NewRequest("GET", chap.url, nil)
	req.Header.Set("User-Agent", GetRandomUserAgent())
	client := http.DefaultClient
	res, e := client.Do(req)
	if e != nil {
		fmt.Errorf("Get请求%s返回错误:%s", chap.url, e)
		return
	}

	//stmt, _ := db.Prepare("replace  INTO mymvc_chapter(`id`,`title`,`content`,`book_id`) VALUES (?,?,?,?)")
	defer func() {
		//stmt.Close()
		//waitgroup2.Done()
		if r := recover(); r != nil {
			log.Println("[E]", r)
		}
	}()

	if res.StatusCode == 200 {
		doc, _ := goquery.NewDocumentFromResponse(res)
		content, _ := doc.Find("#contents").Html()

		//tx, _ := db.Begin()

		//stmt.Exec("张三", 20)
		ret, err := db.Exec("INSERT INTO mymvc_chapter(`id`,`title`,`content`,`book_id`) VALUES (?,?,?,?)", getChapterId(chap.url), chap.title, content, chap.bookid)
		//ret, err := stmt.Exec(getChapterId(chap.url), chap.title, content, chap.bookid)
		if err != nil {
			fmt.Printf("insert data error: %v\n", err)
		}
		if LastInsertId, err := ret.LastInsertId(); nil == err {
			fmt.Println("chapid:", LastInsertId)
		}
	}
	return
}

func getImgName(src string) string {
	//图片正则
	reg, _ := regexp.Compile(`(\w|\d|_)*.jpg`)
	name := reg.FindStringSubmatch(src)[0]
	//fmt.Print(name)
	return name
}

func getTimeStamp(toBeCharge string) int64 {
	toBeCharge = string([]rune(toBeCharge)[1:])
	var sr int64 = 0
	the_time, err := time.ParseInLocation("2006-01-02 15:04:05", toBeCharge, time.Local)
	if err == nil {
		sr = the_time.Unix()
		//fmt.Println(sr)
	}
	return sr
}

func downpic(src string) {
	//通过http请求获取图片的流文件
	fmt.Println("下载封面图片", getImgName(src), src)
	resp, _ := http.Get(src)
	body, _ := ioutil.ReadAll(resp.Body)
	out, _ := os.Create("./sss/" + getImgName(src))
	io.Copy(out, bytes.NewReader(body))
}

func getCateId(cate string) int {
	switch cate {
	case "玄幻奇幻":
		return 1
	case "武侠仙侠":
		return 2
	case "都市言情":
		return 3
	case "历史军事":
		return 4
	case "网游竞技":
		return 5
	case "恐怖灵异":
		return 6
	case "女频频道":
		return 8
	case "其他小说":
		return 9
	default:
		return 9
	}
}

var db = &sql.DB{}

//var chapPre = &sql.Stmt{}

func init() {
	db, _ = sql.Open("mysql", "root:root@tcp(localhost:3306)/dfsy_book?charset=utf8mb4")

	//db.SetMaxOpenConns(2000)
	//db.SetMaxIdleConns(1000)

	//bookPre, _ := db.Prepare("INSERT INTO mymvc_book(`title`,`author`,`pic`,`desc`,`w_status`,`cate_id`,`lasttime`) VALUES (?,?,?,?,?,?,?)")
	//chapPre, _ := db.Prepare("INSERT user SET username=?,password=?")
}

func main() {

	//go getChapterList("https://www.23us.so/files/article/html/27/27376/index.html", 100)
	// 产生任务
	go func() {
		for i := 1; i < 1425; i++ {
			//i := 1
			Spy("https://www.23us.so/top/lastupdate_", i)
		}
		fmt.Println("关闭信道1")
		close(urlChannel)
	}()
	//go Spy("http://www.iteye.com/")
	for url := range urlChannel {

		//fmt.Println("routines num = ", runtime.NumGoroutine(), "chan len = ", len(urlChannel)) //通过runtime可以获取当前运行时的一些相关参数等
		//fmt.Println(url)
		go Book(url)
		//go Spy(url)
	}

	//stmt, _ := db.Prepare("INSERT INTO mymvc_chapter(`id`,`title`,`content`,`book_id`) VALUES (?,?,?,?)")

	//分享章节列表

	for chapterItem := range chapterChannel {
		//fmt.Println(chapterItem)
		execChans <- true
		time.Sleep(50 * time.Millisecond)
		fmt.Println("routines num = ", runtime.NumGoroutine(), "chan2 len = ", len(chapterChannel)) //通过runtime可以获取当前运行时的一些相关参数等
		go getChapterContent(chapterItem)
		//go Book(url)
		//go Spy(url)
	}
	close(execChans) // 关闭执行信号

	//waitgroup2.Wait()
	fmt.Println("爬虫 累死了~~~")

}
