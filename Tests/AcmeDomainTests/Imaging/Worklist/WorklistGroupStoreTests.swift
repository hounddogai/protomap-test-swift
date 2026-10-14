@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWorklistGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WorklistGroupStore = Imaging.newMemoryWorklistGroupStore()
        let item = Imaging.newWorklistGroup("code-62", title: "title-615")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
