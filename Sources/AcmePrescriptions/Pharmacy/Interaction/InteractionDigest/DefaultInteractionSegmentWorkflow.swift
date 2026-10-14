import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves default interaction segments through their life cycle and keeps a journal of what it did.
    final class DefaultInteractionSegmentManager {
        var store: any DefaultInteractionSegmentStore
        var validator: DefaultInteractionSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultInteractionSegmentEngine

        init(store: any DefaultInteractionSegmentStore, validator: DefaultInteractionSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultInteractionSegmentEngine) {
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
                throw Kit.Failure("default interaction segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultInteractionSegmentStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default interaction segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultInteractionSegmentStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default interaction segment \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newDefaultInteractionSegmentManager(_ store: any DefaultInteractionSegmentStore, clock: any Kit.Clocks.Clock) -> DefaultInteractionSegmentManager {
        return DefaultInteractionSegmentManager(
            store: store,
            validator: defaultDefaultInteractionSegmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultInteractionSegmentEngine()
        )
    }
}
