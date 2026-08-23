const http=require("http");

const port=process.env.PORT || 3000;


http.createServer((req,res)=>{

res.writeHead(200,{
"Content-Type":"text/plain"
});

res.end(
"Wispbyte Sing-box Running\n"
);


}).listen(port);


console.log(
"HTTP server running:",
port
);
