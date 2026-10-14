@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCleaningVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CleaningVarianceStore = BedManagement.newMemoryCleaningVarianceStore()
        let item = BedManagement.newCleaningVariance("code-557", label: "label-637")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
