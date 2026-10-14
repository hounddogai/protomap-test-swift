@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryGlobalCleaningVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.GlobalCleaningVarianceStore = BedManagement.newMemoryGlobalCleaningVarianceStore()
        let item = BedManagement.newGlobalCleaningVariance("code-973", label: "label-333")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
