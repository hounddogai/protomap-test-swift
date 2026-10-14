import AcmePlatform
import Foundation

extension Referrals {
    /// Moves primary closure notices through their life cycle and keeps a journal of what it did.
    final class PrimaryClosureNoticeManager {
        var store: any PrimaryClosureNoticeStore
        var validator: PrimaryClosureNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryClosureNoticeEngine

        init(store: any PrimaryClosureNoticeStore, validator: PrimaryClosureNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryClosureNoticeEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary closure notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryClosureNoticeStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary closure notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryClosureNoticeStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary closure notice \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newPrimaryClosureNoticeManager(_ store: any PrimaryClosureNoticeStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PrimaryClosureNoticeManager {
        return PrimaryClosureNoticeManager(
            store: store,
            validator: defaultPrimaryClosureNoticeValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryClosureNoticeEngine(flags)
        )
    }
}
