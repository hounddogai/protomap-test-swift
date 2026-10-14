@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryStrictProgramManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.StrictProgramManifestStore = CareManagement.newMemoryStrictProgramManifestStore()
        let item = CareManagement.newStrictProgramManifest("code-340", label: "label-543")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
