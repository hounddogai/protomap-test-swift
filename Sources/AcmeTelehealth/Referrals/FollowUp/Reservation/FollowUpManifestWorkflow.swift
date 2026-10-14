import AcmePlatform
import Foundation

extension Referrals {
    /// Moves follow up manifests through their life cycle and keeps a journal of what it did.
    final class FollowUpManifestService {
        var store: any FollowUpManifestStore
        var validator: FollowUpManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FollowUpManifestStore, validator: FollowUpManifestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FollowUpManifestStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FollowUpManifestStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newFollowUpManifestService(_ store: any FollowUpManifestStore, clock: any Kit.Clocks.Clock) -> FollowUpManifestService {
        return FollowUpManifestService(
            store: store,
            validator: defaultFollowUpManifestValidator(),
            clock: clock,
            journal: []
        )
    }
}
