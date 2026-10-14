import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves pending denial manifests through their life cycle and keeps a journal of what it did.
    final class PendingDenialManifestWorkflow {
        var store: any PendingDenialManifestStore
        var validator: PendingDenialManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingDenialManifestStore, validator: PendingDenialManifestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending denial manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingDenialManifestStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending denial manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingDenialManifestStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newPendingDenialManifestWorkflow(_ store: any PendingDenialManifestStore, clock: any Kit.Clocks.Clock) -> PendingDenialManifestWorkflow {
        return PendingDenialManifestWorkflow(
            store: store,
            validator: defaultPendingDenialManifestValidator(),
            clock: clock,
            journal: []
        )
    }
}
