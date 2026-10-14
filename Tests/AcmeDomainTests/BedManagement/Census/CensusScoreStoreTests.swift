@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCensusScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CensusScoreStore = BedManagement.newMemoryCensusScoreStore()
        let item = BedManagement.newCensusScore("code-979", label: "label-774")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
