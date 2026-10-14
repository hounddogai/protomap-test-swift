@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCareGapBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CareGapBundleStore = CareManagement.newMemoryCareGapBundleStore()
        let item = CareManagement.newCareGapBundle("code-300", label: "label-140")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
