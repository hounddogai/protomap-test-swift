import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves inventory exceptions through their life cycle and keeps a journal of what it did.
    final class InventoryExceptionService {
        var store: any InventoryExceptionStore
        var validator: InventoryExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: InventoryExceptionEngine

        init(store: any InventoryExceptionStore, validator: InventoryExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: InventoryExceptionEngine) {
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
                throw Kit.Failure("inventory exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(InventoryExceptionStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("inventory exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(InventoryExceptionStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("inventory exception \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newInventoryExceptionService(_ store: any InventoryExceptionStore, clock: any Kit.Clocks.Clock) -> InventoryExceptionService {
        return InventoryExceptionService(
            store: store,
            validator: defaultInventoryExceptionValidator(),
            clock: clock,
            journal: [],
            engine: defaultInventoryExceptionEngine()
        )
    }
}
