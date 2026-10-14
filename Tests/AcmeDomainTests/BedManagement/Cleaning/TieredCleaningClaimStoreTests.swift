@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryTieredCleaningClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.TieredCleaningClaimStore = BedManagement.newMemoryTieredCleaningClaimStore()
        let item = BedManagement.newTieredCleaningClaim("code-453", label: "label-96")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
