@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRegionalAlertBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RegionalAlertBaselineStore = ClinicalOps.newMemoryRegionalAlertBaselineStore()
        let item = ClinicalOps.newRegionalAlertBaseline("code-598", label: "label-257")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
