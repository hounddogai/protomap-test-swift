@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryDefaultBedBoardVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.DefaultBedBoardVarianceStore = BedManagement.newMemoryDefaultBedBoardVarianceStore()
        let item = BedManagement.newDefaultBedBoardVariance("code-121", label: "label-81")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
