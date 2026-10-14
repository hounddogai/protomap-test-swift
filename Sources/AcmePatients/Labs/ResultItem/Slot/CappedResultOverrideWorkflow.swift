import AcmePlatform
import Foundation

extension Labs {
    /// Moves capped result overrides through their life cycle and keeps a journal of what it did.
    final class CappedResultOverrideService {
        var store: any CappedResultOverrideStore
        var validator: CappedResultOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedResultOverrideEngine

        init(store: any CappedResultOverrideStore, validator: CappedResultOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedResultOverrideEngine) {
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
                throw Kit.Failure("capped result override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedResultOverrideStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped result override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedResultOverrideStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped result override \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newCappedResultOverrideService(_ store: any CappedResultOverrideStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CappedResultOverrideService {
        return CappedResultOverrideService(
            store: store,
            validator: defaultCappedResultOverrideValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedResultOverrideEngine(flags)
        )
    }
}
