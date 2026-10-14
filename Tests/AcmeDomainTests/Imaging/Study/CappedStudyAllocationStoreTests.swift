@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCappedStudyAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CappedStudyAllocationStore = Imaging.newMemoryCappedStudyAllocationStore()
        let item = Imaging.newCappedStudyAllocation("code-248", label: "label-521")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
