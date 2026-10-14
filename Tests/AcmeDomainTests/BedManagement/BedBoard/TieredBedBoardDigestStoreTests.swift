@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryTieredBedBoardDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.TieredBedBoardDigestStore = BedManagement.newMemoryTieredBedBoardDigestStore()
        let item = BedManagement.newTieredBedBoardDigest("code-943", name: "name-800")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
