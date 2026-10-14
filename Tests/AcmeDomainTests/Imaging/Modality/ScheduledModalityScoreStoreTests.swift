@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryScheduledModalityScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ScheduledModalityScoreStore = Imaging.newMemoryScheduledModalityScoreStore()
        let item = Imaging.newScheduledModalityScore("code-441", title: "title-295")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
