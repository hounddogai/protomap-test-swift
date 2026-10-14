import AcmePlatform
import Foundation

extension Staffing {
    /// Moves float pool manifests through their life cycle and keeps a journal of what it did.
    final class FloatPoolManifestDesk {
        var store: any FloatPoolManifestStore
        var validator: FloatPoolManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FloatPoolManifestEngine

        init(store: any FloatPoolManifestStore, validator: FloatPoolManifestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FloatPoolManifestEngine) {
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
                throw Kit.Failure("float pool manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FloatPoolManifestStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FloatPoolManifestStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool manifest \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newFloatPoolManifestDesk(_ store: any FloatPoolManifestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FloatPoolManifestDesk {
        return FloatPoolManifestDesk(
            store: store,
            validator: defaultFloatPoolManifestValidator(),
            clock: clock,
            journal: [],
            engine: defaultFloatPoolManifestEngine(flags)
        )
    }
}
