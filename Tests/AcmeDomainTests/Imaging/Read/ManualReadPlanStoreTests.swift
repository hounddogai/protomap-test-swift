@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryManualReadPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ManualReadPlanStore = Imaging.newMemoryManualReadPlanStore()
        let item = Imaging.newManualReadPlan("code-524", name: "name-775")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
