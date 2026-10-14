@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryRegionalStudyBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.RegionalStudyBaselineStore = Imaging.newMemoryRegionalStudyBaselineStore()
        let item = Imaging.newRegionalStudyBaseline("code-639", name: "name-657")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
