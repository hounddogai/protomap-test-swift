import AcmePlatform
import Foundation

extension Imaging {
    /// Moves default modality targets through their life cycle and keeps a journal of what it did.
    final class DefaultModalityTargetService {
        var store: any DefaultModalityTargetStore
        var validator: DefaultModalityTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultModalityTargetEngine

        init(store: any DefaultModalityTargetStore, validator: DefaultModalityTargetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultModalityTargetEngine) {
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
                throw Kit.Failure("default modality target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultModalityTargetStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default modality target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultModalityTargetStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default modality target \(code) not found")
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
                if item.updatedAt > cutoff {
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

    static func newDefaultModalityTargetService(_ store: any DefaultModalityTargetStore, clock: any Kit.Clocks.Clock) -> DefaultModalityTargetService {
        return DefaultModalityTargetService(
            store: store,
            validator: defaultDefaultModalityTargetValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultModalityTargetEngine()
        )
    }
}
