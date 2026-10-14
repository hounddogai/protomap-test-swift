@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryReadPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ReadPlanStore = Imaging.newMemoryReadPlanStore()
        let item = Imaging.newReadPlan("code-582", title: "title-745")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
