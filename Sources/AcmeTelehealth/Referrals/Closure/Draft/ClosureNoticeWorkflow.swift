import AcmePlatform
import Foundation

extension Referrals {
    /// Moves closure notices through their life cycle and keeps a journal of what it did.
    final class ClosureNoticeCoordinator {
        var store: any ClosureNoticeStore
        var validator: ClosureNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ClosureNoticeEngine

        init(store: any ClosureNoticeStore, validator: ClosureNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ClosureNoticeEngine) {
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
                throw Kit.Failure("closure notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClosureNoticeStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClosureNoticeStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure notice \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newClosureNoticeCoordinator(_ store: any ClosureNoticeStore, clock: any Kit.Clocks.Clock) -> ClosureNoticeCoordinator {
        return ClosureNoticeCoordinator(
            store: store,
            validator: defaultClosureNoticeValidator(),
            clock: clock,
            journal: [],
            engine: defaultClosureNoticeEngine()
        )
    }
}
