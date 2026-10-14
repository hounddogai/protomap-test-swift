@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryModalityMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ModalityMilestoneStore = Imaging.newMemoryModalityMilestoneStore()
        let item = Imaging.newModalityMilestone("code-850", label: "label-258")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
