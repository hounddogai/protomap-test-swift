import AcmePlatform
import Foundation

extension Imaging {
    /// Moves default care protocol slots through their life cycle and keeps a journal of what it did.
    final class DefaultCareProtocolSlotWorkflow {
        var store: any DefaultCareProtocolSlotStore
        var validator: DefaultCareProtocolSlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultCareProtocolSlotEngine

        init(store: any DefaultCareProtocolSlotStore, validator: DefaultCareProtocolSlotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultCareProtocolSlotEngine) {
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
                throw Kit.Failure("default care protocol slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultCareProtocolSlotStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default care protocol slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultCareProtocolSlotStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default care protocol slot \(code) not found")
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

    static func newDefaultCareProtocolSlotWorkflow(_ store: any DefaultCareProtocolSlotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DefaultCareProtocolSlotWorkflow {
        return DefaultCareProtocolSlotWorkflow(
            store: store,
            validator: defaultDefaultCareProtocolSlotValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultCareProtocolSlotEngine(flags)
        )
    }
}
