import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves primary cleaning manifests through their life cycle and keeps a journal of what it did.
    final class PrimaryCleaningManifestDesk {
        var store: any PrimaryCleaningManifestStore
        var validator: PrimaryCleaningManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PrimaryCleaningManifestStore, validator: PrimaryCleaningManifestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("primary cleaning manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryCleaningManifestStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary cleaning manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryCleaningManifestStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newPrimaryCleaningManifestDesk(_ store: any PrimaryCleaningManifestStore, clock: any Kit.Clocks.Clock) -> PrimaryCleaningManifestDesk {
        return PrimaryCleaningManifestDesk(
            store: store,
            validator: defaultPrimaryCleaningManifestValidator(),
            clock: clock,
            journal: []
        )
    }
}
