import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves statement segments through their life cycle and keeps a journal of what it did.
    final class StatementSegmentService {
        var store: any StatementSegmentStore
        var validator: StatementSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StatementSegmentStore, validator: StatementSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("statement segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StatementSegmentStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("statement segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StatementSegmentStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newStatementSegmentService(_ store: any StatementSegmentStore, clock: any Kit.Clocks.Clock) -> StatementSegmentService {
        return StatementSegmentService(
            store: store,
            validator: defaultStatementSegmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
