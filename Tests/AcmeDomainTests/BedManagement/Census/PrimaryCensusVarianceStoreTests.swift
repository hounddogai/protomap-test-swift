@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryPrimaryCensusVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.PrimaryCensusVarianceStore = BedManagement.newMemoryPrimaryCensusVarianceStore()
        let item = BedManagement.newPrimaryCensusVariance("code-566", label: "label-251")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
