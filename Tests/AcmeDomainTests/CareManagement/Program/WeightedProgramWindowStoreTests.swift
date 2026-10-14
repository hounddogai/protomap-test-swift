@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryWeightedProgramWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.WeightedProgramWindowStore = CareManagement.newMemoryWeightedProgramWindowStore()
        let item = CareManagement.newWeightedProgramWindow("code-473", label: "label-159")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
