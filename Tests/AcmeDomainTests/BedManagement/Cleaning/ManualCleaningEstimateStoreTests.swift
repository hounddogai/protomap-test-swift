@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryManualCleaningEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.ManualCleaningEstimateStore = BedManagement.newMemoryManualCleaningEstimateStore()
        let item = BedManagement.newManualCleaningEstimate("code-504", name: "name-301")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
