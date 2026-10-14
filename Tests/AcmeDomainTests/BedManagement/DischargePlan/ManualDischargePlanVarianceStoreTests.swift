@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryManualDischargePlanVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.ManualDischargePlanVarianceStore = BedManagement.newMemoryManualDischargePlanVarianceStore()
        let item = BedManagement.newManualDischargePlanVariance("code-531", label: "label-620")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
