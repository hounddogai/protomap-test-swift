@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryBedBoardClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.BedBoardClaimStore = BedManagement.newMemoryBedBoardClaimStore()
        let item = BedManagement.newBedBoardClaim("code-804", name: "name-638")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
