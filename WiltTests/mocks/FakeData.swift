@testable import Wilt

enum FakeData {
    static var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let items: [TopArtistData] = [
        TopArtistData(
            topArtist: "Pinegrove",
            count: 99,
            date: formatter.date(from: "2019-02-25")!,
            week: "09-2019",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!
        ),
        TopArtistData(
            topArtist: "Bon Iver",
            count: 12,
            date: formatter.date(from: "2018-12-25")!,
            week: "52-2018",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!
        ),
        TopArtistData(
            topArtist: "Death Grips",
            count: 78,
            date: formatter.date(from: "2018-10-21")!,
            week: "43-2018",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!
        ),
        TopArtistData(
            topArtist: "Twin Peaks",
            count: 9,
            date: formatter.date(from: "2018-09-01")!,
            week: "35-2018",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!
        ),
        TopArtistData(
            topArtist: "Danny Brown",
            count: 12,
            date: formatter.date(from: "2018-06-11")!,
            week: "24-2018",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!
        ),
        TopArtistData(
            topArtist: "Show Me The Body",
            count: 90,
            date: formatter.date(from: "2018-06-01")!,
            week: "22-2018",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!
        ),
        TopArtistData(
            topArtist: "Manchester Orchestra",
            count: 16,
            date: formatter.date(from: "2018-04-08")!,
            week: "15-2018",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!
        ),
        TopArtistData(
            topArtist: "Grimes",
            count: 42,
            date: formatter.date(from: "2018-03-09")!,
            week: "10-2018",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!
        ),
        TopArtistData(
            topArtist: "Europe",
            count: 33,
            date: formatter.date(from: "2018-02-19")!,
            week: "08-2018",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!
        ),
        TopArtistData(
            topArtist: "Beastie Boys",
            count: 2,
            date: formatter.date(from: "2018-01-30")!,
            week: "05-2018",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!
        ),
        TopArtistData(
            topArtist: "Tierra Whack",
            count: 4,
            date: formatter.date(from: "2018-01-10")!,
            week: "02-2018",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!
        ),
    ]
}
