@testable import Wilt

enum FakeData {
    static var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        return formatter
    }()

    static let items: [TopArtistData] = [
        TopArtistData(
            topArtist: "Pinegrove",
            count: 99,
            date: formatter.date(from: "2019-02-25")!,
            week: "09-2019",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!
        ),
        TopArtistData(
            topArtist: "Bon Iver",
            count: 12,
            date: formatter.date(from: "2018-12-25")!,
            week: "52-2018",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!
        ),
        TopArtistData(
            topArtist: "Death Grips",
            count: 78,
            date: formatter.date(from: "2018-10-21")!,
            week: "43-2018",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!
        ),
        TopArtistData(
            topArtist: "Twin Peaks",
            count: 9,
            date: formatter.date(from: "2018-09-01")!,
            week: "35-2018",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!
        ),
        TopArtistData(
            topArtist: "Danny Brown",
            count: 12,
            date: formatter.date(from: "2018-06-11")!,
            week: "24-2018",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!
        ),
        TopArtistData(
            topArtist: "Show Me The Body",
            count: 90,
            date: formatter.date(from: "2018-06-01")!,
            week: "22-2018",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!
        ),
        TopArtistData(
            topArtist: "Manchester Orchestra",
            count: 16,
            date: formatter.date(from: "2018-04-08")!,
            week: "15-2018",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!
        ),
        TopArtistData(
            topArtist: "Grimes",
            count: 42,
            date: formatter.date(from: "2018-03-09")!,
            week: "10-2018",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!
        ),
        TopArtistData(
            topArtist: "Europe",
            count: 33,
            date: formatter.date(from: "2018-02-19")!,
            week: "08-2018",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!
        ),
        TopArtistData(
            topArtist: "Beastie Boys",
            count: 2,
            date: formatter.date(from: "2018-01-30")!,
            week: "05-2018",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!
        ),
        TopArtistData(
            topArtist: "Tierra Whack",
            count: 4,
            date: formatter.date(from: "2018-01-10")!,
            week: "02-2018",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!
        ),
    ]

    static var listenLaterItems: [ListenLaterArtist] {
        FakeData.items.map {
            ListenLaterArtist(
                name: $0.topArtist,
                externalURL: $0.externalURL,
                imageURL: $0.imageURL
            )
        }
    }

    static let historyItems: [TrackHistoryData] = [
        TrackHistoryData(
            songName: "Angelina",
            artistName: "Pinegrove",
            date: formatter.date(from: "2019-02-25")!,
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!,
            trackID: "not_a_real_track_id"
        ),
        TrackHistoryData(
            songName: "715 Creeks",
            artistName: "Bon Iver",
            date: formatter.date(from: "2018-12-25")!,
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!,
            trackID: "not_a_real_track_id"
        ),
        TrackHistoryData(
            songName: "Turned Off",
            artistName: "Death Grips",
            date: formatter.date(from: "2018-10-21")!,
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!,
            trackID: "not_a_real_track_id"
        ),
        TrackHistoryData(
            songName: "Making Breakfast",
            artistName: "Twin Peaks",
            date: formatter.date(from: "2018-09-01")!,
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!,
            trackID: "not_a_real_track_id"
        ),
        TrackHistoryData(
            songName: "Dirty Laundry",
            artistName: "Danny Brown",
            date: formatter.date(from: "2018-06-11")!,
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!,
            trackID: "not_a_real_track_id"
        ),
        TrackHistoryData(
            songName: "Death Sounds 2",
            artistName: "Show Me The Body",
            date: formatter.date(from: "2018-06-01")!,
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!,
            trackID: "not_a_real_track_id"
        ),
        TrackHistoryData(
            songName: "Apprehension",
            artistName: "Manchester Orchestra",
            date: formatter.date(from: "2018-04-08")!,
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!,
            trackID: "not_a_real_track_id"
        ),
        TrackHistoryData(
            songName: "4AEM",
            artistName: "Grimes",
            date: formatter.date(from: "2018-03-09")!,
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!,
            trackID: "not_a_real_track_id"
        ),
        TrackHistoryData(
            songName: "Final Countdown",
            artistName: "Europe",
            date: formatter.date(from: "2018-02-19")!,
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!,
            trackID: "not_a_real_track_id"
        ),
        TrackHistoryData(
            songName: "Do It",
            artistName: "Beastie Boys",
            date: formatter.date(from: "2018-01-30")!,
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!,
            trackID: "not_a_real_track_id"
        ),
        TrackHistoryData(
            songName: "Black Nails",
            artistName: "Tierra Whack",
            date: formatter.date(from: "2018-01-10")!,
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!,
            trackID: "not_a_real_track_id"
        ),
    ]
}
