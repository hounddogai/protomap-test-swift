@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryRegionalStudyRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.RegionalStudyRollupStore = Imaging.newMemoryRegionalStudyRollupStore()
        let item = Imaging.newRegionalStudyRollup("code-868", label: "label-748")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
