@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryReadMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ReadMilestoneStore = Imaging.newMemoryReadMilestoneStore()
        let item = Imaging.newReadMilestone("code-469", name: "name-117")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
