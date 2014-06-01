module std.logger.templatelogger;

public import std.logger.core;
import std.functional : unaryFun;
import std.string;
import std.format;
import std.array;
import std.range;

public void defaultFormatter(T,F)(ref T t, ref F payload) @trusted
{

    size_t fnIdx = payload.file.lastIndexOf('/') + 1;
    size_t funIdx = payload.funcName.lastIndexOf('.') + 1;
    formattedWrite(t, "%s:%s:%s:%u %s",payload.timestamp.toISOExtString(),
        payload.file[fnIdx .. $], payload.funcName[funIdx .. $],
        payload.line, payload.msg);
}

class TemplateLogger(Sink, alias Formatter, alias Filter = a => true) : Logger 
{
    protected Sink sink;
    private alias filterFun = unaryFun!Filter;

    public this(Sink sink, const LogLevel lv = LogLevel.info)
    {
        this(sink, "", lv);
    }

    public this(Sink sink, string name, const LogLevel lv = LogLevel.info)
    {
        super(name, lv);
        this.sink = sink;
    }

    public override void writeLogMsg(ref LoggerPayload payload) 
    {
        version(DisableTemplateLogging)
        {
        }
        else
        {
            if (filterFun(payload))
            {
                Formatter(this.sink, payload);
            }
        }
    }
}

unittest 
{
    auto app = appender!string();

    alias defaultF = defaultFormatter!(Appender!string, Logger.LoggerPayload);
    auto l = new TemplateLogger!(Appender!string, defaultF, 
        (a) => true)(app);
    l.log("Hello");

    assert(app.data().indexOf("Hello") != -1);
}
