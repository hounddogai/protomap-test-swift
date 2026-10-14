@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAdaptiveCareGapBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AdaptiveCareGapBundleStore = CareManagement.newMemoryAdaptiveCareGapBundleStore()
        let item = CareManagement.newAdaptiveCareGapBundle("code-413", label: "label-329")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
