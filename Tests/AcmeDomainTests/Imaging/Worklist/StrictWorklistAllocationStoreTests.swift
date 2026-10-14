@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStrictWorklistAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StrictWorklistAllocationStore = Imaging.newMemoryStrictWorklistAllocationStore()
        let item = Imaging.newStrictWorklistAllocation("code-404", name: "name-175")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
