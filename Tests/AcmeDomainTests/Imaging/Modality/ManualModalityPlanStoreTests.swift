@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryManualModalityPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ManualModalityPlanStore = Imaging.newMemoryManualModalityPlanStore()
        let item = Imaging.newManualModalityPlan("code-87", title: "title-893")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
