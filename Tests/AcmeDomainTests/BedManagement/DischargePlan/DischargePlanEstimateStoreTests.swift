@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryDischargePlanEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.DischargePlanEstimateStore = BedManagement.newMemoryDischargePlanEstimateStore()
        let item = BedManagement.newDischargePlanEstimate("code-147", label: "label-277")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
