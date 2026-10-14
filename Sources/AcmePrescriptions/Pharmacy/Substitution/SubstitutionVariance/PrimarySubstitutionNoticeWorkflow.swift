import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves primary substitution notices through their life cycle and keeps a journal of what it did.
    final class PrimarySubstitutionNoticeCoordinator {
        var store: any PrimarySubstitutionNoticeStore
        var validator: PrimarySubstitutionNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimarySubstitutionNoticeEngine

        init(store: any PrimarySubstitutionNoticeStore, validator: PrimarySubstitutionNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimarySubstitutionNoticeEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary substitution notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimarySubstitutionNoticeStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary substitution notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimarySubstitutionNoticeStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary substitution notice \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newPrimarySubstitutionNoticeCoordinator(_ store: any PrimarySubstitutionNoticeStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PrimarySubstitutionNoticeCoordinator {
        return PrimarySubstitutionNoticeCoordinator(
            store: store,
            validator: defaultPrimarySubstitutionNoticeValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimarySubstitutionNoticeEngine(flags)
        )
    }
}
