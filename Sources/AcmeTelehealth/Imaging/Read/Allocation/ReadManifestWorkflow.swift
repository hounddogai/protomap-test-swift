import AcmePlatform
import Foundation

extension Imaging {
    /// Moves read manifests through their life cycle and keeps a journal of what it did.
    final class ReadManifestDesk {
        var store: any ReadManifestStore
        var validator: ReadManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ReadManifestEngine

        init(store: any ReadManifestStore, validator: ReadManifestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ReadManifestEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("read manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReadManifestStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("read manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReadManifestStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("read manifest \(code) not found")
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

    static func newReadManifestDesk(_ store: any ReadManifestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ReadManifestDesk {
        return ReadManifestDesk(
            store: store,
            validator: defaultReadManifestValidator(),
            clock: clock,
            journal: [],
            engine: defaultReadManifestEngine(flags)
        )
    }
}
