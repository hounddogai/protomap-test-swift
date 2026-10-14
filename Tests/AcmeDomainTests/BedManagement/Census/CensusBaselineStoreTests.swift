@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCensusBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CensusBaselineStore = BedManagement.newMemoryCensusBaselineStore()
        let item = BedManagement.newCensusBaseline("code-216", label: "label-490")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
