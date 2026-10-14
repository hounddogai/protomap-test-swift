@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWorklistRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WorklistRollupStore = Imaging.newMemoryWorklistRollupStore()
        let item = Imaging.newWorklistRollup("code-384", title: "title-367")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
