import AcmePlatform
import Foundation

extension Imaging {
    /// Moves weighted read profiles through their life cycle and keeps a journal of what it did.
    final class WeightedReadProfileManager {
        var store: any WeightedReadProfileStore
        var validator: WeightedReadProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedReadProfileEngine

        init(store: any WeightedReadProfileStore, validator: WeightedReadProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedReadProfileEngine) {
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
                throw Kit.Failure("weighted read profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedReadProfileStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted read profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedReadProfileStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted read profile \(code) not found")
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

    static func newWeightedReadProfileManager(_ store: any WeightedReadProfileStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WeightedReadProfileManager {
        return WeightedReadProfileManager(
            store: store,
            validator: defaultWeightedReadProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedReadProfileEngine(flags)
        )
    }
}
