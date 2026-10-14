import AcmePlatform
import Foundation

extension Referrals {
    /// Moves pending slot manifests through their life cycle and keeps a journal of what it did.
    final class PendingSlotManifestCoordinator {
        var store: any PendingSlotManifestStore
        var validator: PendingSlotManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingSlotManifestStore, validator: PendingSlotManifestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("pending slot manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingSlotManifestStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending slot manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingSlotManifestStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newPendingSlotManifestCoordinator(_ store: any PendingSlotManifestStore, clock: any Kit.Clocks.Clock) -> PendingSlotManifestCoordinator {
        return PendingSlotManifestCoordinator(
            store: store,
            validator: defaultPendingSlotManifestValidator(),
            clock: clock,
            journal: []
        )
    }
}
