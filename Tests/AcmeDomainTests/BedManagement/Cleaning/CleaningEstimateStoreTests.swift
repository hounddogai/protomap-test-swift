@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCleaningEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CleaningEstimateStore = BedManagement.newMemoryCleaningEstimateStore()
        let item = BedManagement.newCleaningEstimate("code-667", name: "name-36")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
