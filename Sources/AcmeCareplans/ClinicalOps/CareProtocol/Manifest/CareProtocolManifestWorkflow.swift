import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves care protocol manifests through their life cycle and keeps a journal of what it did.
    final class CareProtocolManifestWorkflow {
        var store: any CareProtocolManifestStore
        var validator: CareProtocolManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CareProtocolManifestStore, validator: CareProtocolManifestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareProtocolManifestStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareProtocolManifestStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newCareProtocolManifestWorkflow(_ store: any CareProtocolManifestStore, clock: any Kit.Clocks.Clock) -> CareProtocolManifestWorkflow {
        return CareProtocolManifestWorkflow(
            store: store,
            validator: defaultCareProtocolManifestValidator(),
            clock: clock,
            journal: []
        )
    }
}
