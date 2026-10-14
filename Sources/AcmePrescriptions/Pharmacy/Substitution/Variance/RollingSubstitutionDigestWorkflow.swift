import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves rolling substitution digests through their life cycle and keeps a journal of what it did.
    final class RollingSubstitutionDigestService {
        var store: any RollingSubstitutionDigestStore
        var validator: RollingSubstitutionDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RollingSubstitutionDigestStore, validator: RollingSubstitutionDigestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("rolling substitution digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingSubstitutionDigestStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling substitution digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingSubstitutionDigestStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newRollingSubstitutionDigestService(_ store: any RollingSubstitutionDigestStore, clock: any Kit.Clocks.Clock) -> RollingSubstitutionDigestService {
        return RollingSubstitutionDigestService(
            store: store,
            validator: defaultRollingSubstitutionDigestValidator(),
            clock: clock,
            journal: []
        )
    }
}
