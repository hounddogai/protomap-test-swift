import AcmePlatform
import Foundation

extension Referrals {
    /// Moves rolling closure notices through their life cycle and keeps a journal of what it did.
    final class RollingClosureNoticeDesk {
        var store: any RollingClosureNoticeStore
        var validator: RollingClosureNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingClosureNoticeEngine

        init(store: any RollingClosureNoticeStore, validator: RollingClosureNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingClosureNoticeEngine) {
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
                throw Kit.Failure("rolling closure notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingClosureNoticeStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling closure notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingClosureNoticeStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling closure notice \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newRollingClosureNoticeDesk(_ store: any RollingClosureNoticeStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RollingClosureNoticeDesk {
        return RollingClosureNoticeDesk(
            store: store,
            validator: defaultRollingClosureNoticeValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingClosureNoticeEngine(flags)
        )
    }
}
