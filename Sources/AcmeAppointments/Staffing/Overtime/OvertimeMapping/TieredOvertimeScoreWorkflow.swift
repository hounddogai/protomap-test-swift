import AcmePlatform
import Foundation

extension Staffing {
    /// Moves tiered overtime scores through their life cycle and keeps a journal of what it did.
    final class TieredOvertimeScoreService {
        var store: any TieredOvertimeScoreStore
        var validator: TieredOvertimeScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredOvertimeScoreEngine

        init(store: any TieredOvertimeScoreStore, validator: TieredOvertimeScoreValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredOvertimeScoreEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered overtime score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredOvertimeScoreStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered overtime score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredOvertimeScoreStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered overtime score \(code) not found")
            }
            let result = engine.price(item)
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

    static func newTieredOvertimeScoreService(_ store: any TieredOvertimeScoreStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TieredOvertimeScoreService {
        return TieredOvertimeScoreService(
            store: store,
            validator: defaultTieredOvertimeScoreValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredOvertimeScoreEngine(flags)
        )
    }
}
